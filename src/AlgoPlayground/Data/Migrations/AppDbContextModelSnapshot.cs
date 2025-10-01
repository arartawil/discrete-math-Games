using System;
using AlgoPlayground.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

#nullable disable

namespace AlgoPlayground.Data.Migrations
{
    [DbContext(typeof(AppDbContext))]
    partial class AppDbContextModelSnapshot : ModelSnapshot
    {
        protected override void BuildModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "8.0.0")
                .HasAnnotation("Relational:MaxIdentifierLength", 128);

            SqlServerModelBuilderExtensions.UseIdentityColumns(modelBuilder);

            modelBuilder.Entity("AlgoPlayground.Domain.ScoreEntry", b =>
            {
                b.Property<int>("Id")
                    .ValueGeneratedOnAdd()
                    .HasColumnType("int");

                SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                b.Property<int>("DurationSec")
                    .HasColumnType("int");

                b.Property<int>("GameId")
                    .HasColumnType("int");

                b.Property<int>("Level")
                    .HasColumnType("int");

                b.Property<int>("Points")
                    .HasColumnType("int");

                b.Property<DateTime>("Timestamp")
                    .ValueGeneratedOnAdd()
                    .HasColumnType("datetime2")
                    .HasDefaultValueSql("GETUTCDATE()");

                b.Property<int>("UserProfileId")
                    .HasColumnType("int");

                b.HasKey("Id");

                b.HasIndex("UserProfileId");

                b.ToTable("ScoreEntries");
            });

            modelBuilder.Entity("AlgoPlayground.Domain.UserProfile", b =>
            {
                b.Property<int>("Id")
                    .ValueGeneratedOnAdd()
                    .HasColumnType("int");

                SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                b.Property<DateTime>("CreatedAt")
                    .ValueGeneratedOnAdd()
                    .HasColumnType("datetime2")
                    .HasDefaultValueSql("GETUTCDATE()");

                b.Property<string>("Name")
                    .IsRequired()
                    .HasMaxLength(128)
                    .HasColumnType("nvarchar(128)");

                b.Property<string>("StudentNumber")
                    .IsRequired()
                    .HasMaxLength(32)
                    .HasColumnType("nvarchar(32)");

                b.HasKey("Id");

                b.HasIndex("StudentNumber")
                    .IsUnique();

                b.ToTable("UserProfiles");
            });

            modelBuilder.Entity("AlgoPlayground.Domain.ScoreEntry", b =>
            {
                b.HasOne("AlgoPlayground.Domain.UserProfile", "UserProfile")
                    .WithMany("Scores")
                    .HasForeignKey("UserProfileId")
                    .OnDelete(DeleteBehavior.Cascade)
                    .IsRequired();

                b.Navigation("UserProfile");
            });

            modelBuilder.Entity("AlgoPlayground.Domain.UserProfile", b =>
            {
                b.Navigation("Scores");
            });
#pragma warning restore 612, 618
        }
    }
}
